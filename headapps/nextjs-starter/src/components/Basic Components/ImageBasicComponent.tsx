import { withDatasourceCheck, NextImage as JssImage, ImageField, } from '@sitecore-jss/sitecore-jss-nextjs';
import { ComponentProps } from 'lib/component-props';
import styles from 'src/components/Basic Components/BasicStytes.module.scss'

type ImageBasicComponentProps = ComponentProps & {
    fields: {
        'Image Field': ImageField;
    };
};

const ImageBasicComponent = ({ fields }: ImageBasicComponentProps): JSX.Element => (
    <JssImage field={fields['Image Field']} className={styles['image']} />
);

export default withDatasourceCheck()<ImageBasicComponentProps>(ImageBasicComponent);