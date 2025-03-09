import { Text, RichText, Field } from '@sitecore-jss/sitecore-jss-nextjs';
import { ComponentProps } from 'lib/component-props';
import styles from 'src/components/Basic Components/BasicStytes.module.scss'

type SimpleMastheadProps = ComponentProps & {
    fields: {
        'Masthead Title': Field<string>;
        'Masthead Description': Field<string>;
    };
};

const SimpleMasthead = ({ fields }: SimpleMastheadProps): JSX.Element => (
    <>
        <div className={styles["title-box"]}>
            <Text tag="h1" className={styles["contentTitle"]} field={fields['Masthead Title']} />
        </div>
        <RichText className={styles["contentDescription"]} field={fields['Masthead Description']} />
    </>
);

export default SimpleMasthead;