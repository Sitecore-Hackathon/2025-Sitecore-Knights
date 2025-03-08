import { Placeholder } from '@sitecore-jss/sitecore-jss-nextjs';
import { ComponentProps } from 'lib/component-props';
import styles from 'src/components/Basic Components/BasicStytes.module.scss'

type GeneratedStructureProps = ComponentProps & {
  params: { [key: string]: string };
};

const GeneratedStructure = ({ params, rendering }: GeneratedStructureProps) => {
  const { DynamicPlaceholderId } = params;
  const phKeyMasthead = `gs-masthead-${DynamicPlaceholderId}`;
  const phKeyImage = `gs-image-${DynamicPlaceholderId}`;
  const phKeyRTF = `gs-rtf-${DynamicPlaceholderId}`;
  return (
    <div className={styles['container']}>
      <Placeholder name={phKeyMasthead} rendering={rendering} />
      <br></br>
      <Placeholder name={phKeyImage} rendering={rendering} />
      <br></br>
      <Placeholder name={phKeyRTF} rendering={rendering} />
      <br></br>
    </div>
  );
};

export default GeneratedStructure;