import { withDatasourceCheck, RichTextField, RichText, } from '@sitecore-jss/sitecore-jss-nextjs';
import { ComponentProps } from 'lib/component-props';
import styles from 'src/components/Basic Components/BasicStytes.module.scss'

type RichTextBasicComponentProps = ComponentProps & {
    fields: {
        'Rich Text Field': RichTextField;
    };
};

const RichTextBasicComponent = ({ fields }: RichTextBasicComponentProps): JSX.Element => (
    <RichText field={fields['Rich Text Field']} className={styles['description-box']} />
);

export default withDatasourceCheck()<RichTextBasicComponentProps>(RichTextBasicComponent);